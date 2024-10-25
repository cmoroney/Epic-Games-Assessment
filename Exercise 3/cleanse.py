import pandas as pd

# Import CSV's
installs_raw = pd.read_csv("./raw/installs.csv")
activity_raw = pd.read_csv("./raw/activity.csv")

# Files at a glance
print("activity.csv at a glance: \n")
print(activity_raw.describe())

print("\n installs.csv at a glance: \n")
print(installs_raw.describe())

# print(installs_raw.head())
# activity_raw['PLAY_DATE'].head()

# --------------------------------------------------
# Cleansing
# --------------------------------------------------

# Check for missing data
print("\n")
print("installs.csv null values: ")
print(installs_raw.isnull().sum(), "\n")

print("activity.csv null values: ")
print(activity_raw.isnull().sum(), "\n")

# Check activity table for rows containing id's with missing data
missing_cc_ids = installs_raw[installs_raw['COUNTRY_CODE'].isnull()]['USER_ID']
activity_rows_affected = len(activity_raw[activity_raw['USER_ID'].isin(missing_cc_ids)])

# Check number of rows in activity file affected by null country codes
print(f"Total rows in activity.csv affected by users with null country codes: {activity_rows_affected}")

# Check for dupes
installs_dupes = installs_raw.duplicated().sum()
print(f"installs.csv duplicated rows: {installs_dupes}")

activity_dupes = activity_raw.duplicated().sum()
print(f"activity.csv duplicated rows: {activity_dupes}")

# Check if any user has multiple installs
installs_id_cnt = installs_raw.groupby('USER_ID').size().reset_index(name='count')
print(f"Users with multiple installs: {len(installs_id_cnt[installs_id_cnt['count'] > 1])}")

# Check if activity data has duplicate user/date rows
user_date_dupe = activity_raw[['USER_ID', 'PLAY_DATE']].duplicated().sum()
print(f"Activity rows containing the same user on multiple dates: {user_date_dupe}")

# Combine datasets, matching on USER_ID
raw_merged = pd.merge(activity_raw, installs_raw, on='USER_ID')

# Check for datetimestamp consistency
raw_merged['INSTALL_DATE'].str.contains("[0-9]{2}\/[0-9]{2}\/[0-9]{2} [0-9]{2}:[0-9]{2}", regex=True).sum()
raw_merged['PLAY_DATE'].str.contains("[0-9]{2}\/[0-9]{2}\/[0-9]{2} [0-9]{2}:[0-9]{2}", regex=True).sum()

# Format dates
raw_merged['INSTALL_DATETIME'] = pd.to_datetime(raw_merged['INSTALL_DATE'], format=("%d/%m/%y %H:%M"))
raw_merged['PLAY_DATETIME'] = pd.to_datetime(raw_merged['PLAY_DATE'], format=("%d/%m/%y %H:%M"))

# Check min/max
install_min = raw_merged['INSTALL_DATETIME'].min()
install_max = raw_merged['INSTALL_DATETIME'].max()

activity_min = raw_merged['PLAY_DATETIME'].min()
activity_max = raw_merged['PLAY_DATETIME'].max()

print(f"Install date range: ({install_min}, {install_max})")
print(f"Play date range: ({activity_min}, {activity_max}) ")
print("\n")


# Checking to make sure play times are later than install times. Count of rows that are not
play_before_install = raw_merged[(raw_merged['PLAY_DATETIME'].dt.date < raw_merged['INSTALL_DATETIME'].dt.date)]
print("Number of rows with install date > play date: " + str(len(play_before_install)))
print("Unique user IDs with install date > play date: " + str(len(play_before_install['USER_ID'].unique())))

df = raw_merged

print("Adding date/week/month columns for aggregation...")
df['INSTALL_DATE'] = df['INSTALL_DATETIME'].dt.date
df['INSTALL_WEEK'] = df['INSTALL_DATETIME'].dt.to_period("W").dt.start_time
df['INSTALL_MONTH'] = df['INSTALL_DATETIME'].dt.to_period("M").dt.start_time

# Create truncated time period columns for aggregation
temp = raw_merged.sort_values(by=['PLAY_DATETIME'])
df['PLAY_DATE'] = df['PLAY_DATETIME'].dt.date
df['PLAY_WEEK'] = df['PLAY_DATETIME'].dt.to_period("W").dt.start_time
df['PLAY_MONTH'] = df['PLAY_DATETIME'].dt.to_period("M").dt.start_time

# Create DAU / WAU / MAU data frames
# NOTE: Not used here, transitioned to R for analysis
dau_df = df.groupby('PLAY_DATE')['USER_ID'].nunique()
wau_df = df.groupby('PLAY_WEEK')['USER_ID'].nunique()
mau_df = df.groupby('PLAY_MONTH')['USER_ID'].nunique()

# Number of installs over time
df_installs = df.groupby('INSTALL_DATE')['USER_ID'].nunique()

# Number of installs over time by Country
df_installs_country = df.groupby(['INSTALL_MONTH', 'COUNTRY_CODE'])['USER_ID'].nunique()

# Output to csv
print("Saving file as merged_data.csv...")
df.to_csv("./output/merged_data.csv")
print("Done.")
