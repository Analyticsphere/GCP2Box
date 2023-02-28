# test_api.r
#
# Written by: Jake Peters
# Date: Feb 28, 2023
# Description: 
#      This R code queries some test data from BigQuery, 
#      generates a histogram in a PDF, 
#      authenticates to Box using a custom Box app,
#      and write the PDF to a specified Box folder.
 
library(bigrquery)
library(plumber)
library(boxr)
library(googleCloudStorageR)
library(tools)

#* heartbeat...for testing purposes only. Not required to run analysis.
#* @get /
#* @post /
function(){return("alive")}

#* Runs STAGE test script
#* @get /box_transfer_test_api
#* @post /box_transfer_test_api
function() {

  # Set parameters 
  report_name <- "report.pdf"
  bucket      <- "gs://test_analytics_bucket_jp" 
  project     <- "nih-nci-dceg-connect-stg-5519"  
  billing     <- project # Billing must be same as project
  
  # Simple query.
  query_rec <- "SELECT d_117249500 AS Age 
                FROM `nih-nci-dceg-connect-stg-5519.FlatConnect.participants_JP` 
                WHERE Connect_ID IS NOT NULL"
  
  # BigQuery authorization. Should work smoothly on GCP without any inputs.
  bq_auth() 
  
  # Download some data
  rec_table <- bq_project_query(project, query_rec)
  rec_data  <- bq_table_download(rec_table, bigint = "integer64")
  
  # Write a table to pdf as an example "report". 
  # Add time stamp to report name
  report_fid <- paste0(file_path_sans_ext(report_name),
                       format(Sys.time(), "_%m_%d_%Y"),
                       ".", file_ext(report_name))
  pdf(report_name)    # Opens a PDF
  hist(rec_data$Age) # Write histogram to PDF
  dev.off()          # Closes PDF
  
  # Authenticate with Box and write report pdf to Box folder 
  boxr::box_auth_service(token_file = NULL, token_text = NULL)
  boxr::box_write(object, file_name, dir_id = box_getwd(), description = NULL)
 
  # Authenticate with Google Storage and write report file to bucket
  scope <- c("https://www.googleapis.com/auth/cloud-platform")
  token <- token_fetch(scopes=scope)
  gcs_auth(token=token)
  gcs_upload(report_fid, bucket=bucket, name=report_fid) 
  
  # Return a string for for API testing purposes
  ret_str <- paste("All done. Check", bucket, "for", report_fid)
  print(ret_str)
  return(ret_str) 
}

