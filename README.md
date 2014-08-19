Getting and Cleaning Data - Course Project
==========================================

Hello, gang!

If you're reading this then you went through the same R data gauntlet. Kudos,
and I look forward to reading your scripts to see how *you* do it. That is, how
I *should* do it, next time.

What is this?
-------------
Within this repo there are three scripts:

1.  `README.md`: this lil guy, just here to tell you what's what
2.  `run_analysis.R`: The functions within this script work to
    1. Download and unzip the Samsung Galaxy S smartphone datasets (if desired)
    2. Perform various manipulations and scrubbings of the data
    3. Create a consolidated data set of all average and mean measurements in the data set (with more descriptive activity and measurement labels)
    4. Create a tidy data set of the averages of all values across different subject / activity paris.
3.  `CodeBook.md`: a description of the tidy data set created by functions within `run_analysis.R` and a running description of how that set was created from the source data.


How do I use it?
----------------

### `run_analysis.R`

There are a couple of important functions, in my opinion, within
`run_analysis.R` so I will describe them here. First, though, you should

```r
source("run_analysis.R")
```

This won't do anything on it's own -- it's only function definitions.

You also need the source data. If you don't already have it, you can use the helper function
```r
getdata()
```

This function will create a subdirectory `./data` of the current working directory (if it doesn't already exist), download the source data zipfile, and unzip it under `./data`. All functions in this module allow you to lazily assume this directory structure (*i.e.* `samDir <- ./data/UCI HAR Dataset/`), but can also take the directory path of **YOUR** unzipped data as a parameter.

From here, you can run

1.  `merge_test_and_train(samDataDir=samDir)`: This will load and return a merged combination of the test and train datasets from within `samDir`. It will also clean up the feature names (using the helper function `feature_names` and `features.txt` from within the Samsung data set).

2.  `extract_mean_and_std(samDataDir=samDir)`: The same as 1, but filters the column names (using `grep`) to include only mean and std measurements (and not measurements *of* the mean or std, for what it's worth).

3.  `get_mean_and_std_with_labels(samDataDir=samDir)`: The same as 2, but adds a factor column "activity" of the type of activity being measured in the row, and pulls the name from the `activity_labels.txt` samsung data file. **Use this if you are looking to create the full dataset describe in steps 1-4 of this project!**

4.  `make_tidy_average_dataset(samDataDir=samDir)`: Create the tidy data set asked for in part 5 of this assignment -- a data set of the average of all measurments across each (subject, activity) pair.

5.  `save_tidy_average_dataset(samDataDir=samDir, fOut=fTidy)`: Creates the tidy data set discussed in 4 and saves it in the desired way to the file `fTidy`. **Use this if you are looking to create the tidy data set describe in step 5 of this project!**


### `CodeBook.md`

In case it isn't clear, this is a slightly more in-depth description of the data created by `{make,save}_tidy_average_dataset`. Use it by reading it.

One last thought: I am of the opinion that the feature names as originally presented to us (in `features.txt`) -- while obviously not the prettiest -- are good factor names. They are fully descriptive of the measured quantity in about as concise a way as possible.

**As a result** I haven't changed them much. Going only on a gut hunch, I imagine this may not sit favorably with some. I'd suggest to those that it's somewhat a matter of preference at that point; I've demonstrated the ability to get, manipulate, and combine the values and I believe that to be the spirit of the assignment.
