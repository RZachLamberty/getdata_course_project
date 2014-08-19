# run_analysis.R
#
# From the project description:
#   You should create one R script called run_analysis.R that does the following.
#
#     1.  Merges the training and the test sets to create one data set.
#     2.  Extracts only the measurements on the mean and standard deviation for
#         each measurement.
#     3.  Uses descriptive activity names to name the activities in the data set
#     4.  Appropriately labels the data set with descriptive variable names.
#     5.  Creates a second, independent tidy data set with the average of each
#         variable for each activity and each subject.
#
# The functions are all pretty straight-forward, BUT note the following
#
#   + If you do not yet have the data downloaded and unzipped, run:
#
#       source("run_analysis.R")
#       getdata()
#
#   + Once the data has been downloaded and unzipped, there exists a directory
#     of the form .../UCI HAR Dataset/. Call this "samDataDir". All other
#     functions are based off of this directory, and assume the structure of the
#     data in the unzipped archive.
#
#   + To create the appropriately labeled, merged data set from test and train
#     data saved in the samsung directory "samDataDir" (problems 1 - 4), run:
#
#       source("run_analysis.R")
#       z <- get_mean_and_std_with_labels(samDataDir)
#
#   + To create a tidy data set from the data within "samDataDir" and save it to
#     file "fOut", run
#
#       source("run_analysis.R")
#       save_tidy_average_dataset(samDataDir, fOut)
#
#   + Every singly function will work with the defaults, if you download the
#     data with the getdata() function first

library(plyr)


#--------------------------------#
# 0. Getting and Loading Data    #
#--------------------------------#

# Set a few default directory parameters for later functions
dataDir <- file.path(getwd(), 'data')
fZip <- file.path(dataDir, 'samsung_data.zip')
samDir <- file.path(dataDir, "UCI HAR Dataset")
fTidy <- file.path(dataDir, "samsung_data_tidy.txt")

getdata <- function() {
  # Optional function to acquire and arrange data. Will use the same defaults as
  # the rest of the script

  # set up a local data directory
  if (!file.exists(dataDir)) {
    dir.create(dataDir)
  }

  # Download the source information zip directory
  if (!file.exists(fZip)) {
    download.file(
      url="https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip",
      destfile=fZip,
      method='curl'
    )
  }

  # Unzip the contents of the downloaded files (if they don't already exist)
  if (!file.exists(samDir)) {
    unzip(zipfile=fZip, exdir=dataDir)
  }
}

load_features <- function(samDataDir=samDir) {
  # Load the features from the features file.
  #   inputs:
  #     samDir - The directory of the unzipped samsung data
  #
  # The index is redundant, so don't load it.
  read.table(
    file=file.path(samDataDir, "features.txt"),
    colClasses=c("NULL", NA),
    col.names=c("NULL", "feature.name")
  )
}

load_activity_labs <- function(samDataDir=samDir) {
  # Load the features from the features file.
  #   inputs:
  #     samDir - The directory of the unzipped samsung data
  #
  # The index is redundant, so don't load it.
  read.table(
    file=file.path(samDataDir, "activity_labels.txt"),
    colClasses=c("NULL", NA),
    col.names=c("NULL", "activity")
  )
}


#--------------------------------#
# 1. Merging                     #
#--------------------------------#

merge_measurements <- function(samDataDir=samDir, testOrTrial="test") {
  # merge the different test or train files into one data frame
  #   inputs:
  #     samDataDir  - the head data directory
  #     testOrTrial - the subdirectory (test or trial)

  # File names
  fSubj <- file.path(samDataDir, testOrTrial, paste("subject_", testOrTrial, ".txt", sep=""))
  fX <- file.path(samDataDir, testOrTrial, paste("X_", testOrTrial, ".txt", sep=""))
  fY <- file.path(samDataDir, testOrTrial, paste("y_", testOrTrial, ".txt", sep=""))

  # Load all data
  s <- read.table(fSubj, col.names=c("subject"), colClasses=c("numeric"))
  y <- read.table(fY, col.names=c("activity"), colClasses=c("numeric"))
  x <- read.table(fX, col.names=feature_names(samDataDir))

  # Create and return the joined data frame
  xys <- as.data.frame(cbind(s, y, x))

  # factorize the subject and activity
  xys$subject <- as.factor(xys$subject)
  xys$activity <- as.factor(xys$activity)

  levels(xys$activity) <- load_activity_labs(samDataDir)$activity

  xys
}

merge_test_and_train <- function(samDataDir=samDir) {
  # Load the test and train data and merge them into one data set
  #   inputs:
  #     samDir - The directory of the unzipped samsung data
  rbind(
    merge_measurements(samDir, "test"),
    merge_measurements(samDir, "train")
  )
}

feature_names <- function(samDataDir=samDir) {
  # Load the feature names and clean them up for column-naming purposes
  feats <- load_features(samDataDir)$feature.name

  # Clean up stupid value
  feats <- gsub(
    pattern="tBodyAccJerkMean)",
    replacement="tBodyAccJerkMean",
    x=feats
  )

  # Remove ()
  feats <- gsub(
    pattern="\\(\\)",
    replacement=".measurement",
    x=feats,
  )

  # clean up the ranges for the energy bands measurements
  feats <- gsub(
    pattern="([0-9]+),([0-9]+)",
    replacement="\\1.through.\\2",
    x=feats
  )

  # clean up function listings (x, y)
  feats <- gsub(
    pattern="\\(([a-zA-Z]+),([a-zA-Z]+)\\)",
    replacement=".func.with.\\1.and.\\2.endfunc",
    x=feats
  )
  feats <- gsub(
    pattern="\\(([a-zA-Z]+)\\)",
    replacement=".func.with.\\1.endfunc",
    x=feats
  )

  # Replace all remaining special chars with '.'
  feats <- gsub(
    pattern="\\-|,|\\(|\\)",
    replacement=".",
    x=feats
  )

  feats
}


#--------------------------------#
# 2. Extract only mean and std   #
#--------------------------------#

extract_mean_and_std <- function(samDataDir=samDir) {
  # Load and merge the test and train data sets, and extract only mean and std
  # measurements
  #   inputs:
  #     samDataDir - The directory of the unzipped samsung data
  z <- merge_test_and_train(samDataDir)

  z[, c("activity", "subject", mean_and_std_indices(z))]
}

mean_and_std_indices <- function(z) {
  # Return the column names of the data dictionary which are mean or std
  # measurements
  #   inputs:
  #     z - a data frame with descriptive column names
  grep(
    pattern=".*\\.mean\\.measurement\\..*|.*\\.std\\.measurement\\..*",
    x=names(z),
    value=TRUE
  )
}


#--------------------------------#
# 3. Activity labels             #
#--------------------------------#
# I am of the opinion that this was done in the step #1.


#--------------------------------#
# 4. Descriptive labels          #
#--------------------------------#
# I am of the opinion that this was done in the step #1.

#--------------------------------#
# 5. Tidy data set cleanup       #
#--------------------------------#

make_tidy_average_dataset <- function(samDataDir=samDir) {
  # Create a tidy dataset which holds the averages of every measurment in the
  # original data set
  #   inputs:
  #     samDataDir - The directory of the unzipped samsung data
  z_av <- ddply(
    .data=merge_test_and_train(samDataDir),
    .variable=.(subject, activity),
    .fun=function(x) {colMeans(x[, c(-1, -2)])}
  )
  z_av <- z_av[order(z_av$subject, z_av$activity), ]
  names(z_av) <- c(
    "subject",
    "activity",
    paste("average", names(z_av)[3: ncol(z_av)], sep="_")
  )
  z_av
}

save_tidy_average_dataset <- function(samDataDir=samDir, fOut=fTidy) {
  # Create the tidy data set (as above), but also save it to file
  #   inputs:
  #     samDataDir - The directory of the unzipped samsung data
  #     fOut       - The file to which we should save the tidy data set
  write.table(
    x=make_tidy_average_dataset(samDataDir),
    file=fOut,
    row.names=FALSE
  )
}
