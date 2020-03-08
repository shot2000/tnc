



# ipak function: install and load multiple R packages.
# check to see if packages are installed. Install them if they are not, then load them into the R session.

ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

# usage
packages <- c("ggplot2", "plyr", "reshape2", "RColorBrewer", "scales", "grid","RPostgreSQL","readr","janitor","dplyr")
ipak(packages)


# create a connection
# save the password that we can "hide" it as best as we can by collapsing it
pw <- {
  "BuFan5050"
}

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
# note that "con" will be used later in each connection to the database
con <- dbConnect(drv, dbname = "postgres",
                 host = "localhost", port = 5432,
                 user = "slash", password = pw)
rm(pw) # removes the password

# check for the cartable
dbExistsTable(con, "cartable")
# TRUE

# creates df, a data.frame with the necessary columns


Chicago_TNC_data_trips_Oct2019 <- read_csv("G:/Chicago_Data/Chicago_TNC_data_trips_Oct2019.csv")



#clean up the columns names
#This is important to run because otherwise you end up with a messy postgres db
Chicago_TNC_data_trips_Oct2019 <- clean_names(Chicago_TNC_data_trips_Oct2019)

#converting to tibble
tnc_trip<- tbl_df(Chicago_TNC_data_trips_Oct2019)

# writes df to the PostgreSQL database "postgres", table "cartable" 
dbWriteTable(con, "tnc", 
             value = Chicago_TNC_data_trips_Oct2019, append = FALSE, row.names = FALSE)

# query the data from postgreSQL 
df_postgres <- dbGetQuery(con, "SELECT * FROM public.tnc WHERE trips_pooled = 1" )

df_postgres <- dbGetQuery(con, "SELECT * from public.tnc LIMIT 6" )

# remove table from database
dbSendQuery(con, "drop table tnc")

# compares the two data.frames
identical(Chicago_TNC_data_trips_Oct2019, df_postgres)
# TRUE

# Basic Graph of the Data
require(ggplot2)
ggplot(df_postgres, aes(x = as.factor(cyl), y = mpg, fill = as.factor(cyl))) + 
  geom_boxplot() + theme_bw()

# close the connection
dbDisconnect(con)
dbUnloadDriver(drv)
