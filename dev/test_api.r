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
library(googleCloudStorageR) # googleCloudStorageR and gargle used together
library(gargle)
library(httr)
# Install Daniel Russ' package for interacting with GCP Secret Manager, gsecretR
library(devtools)
devtools::install_github('episphere/gsecretR')
library(gsecretR)


# #* heartbeat...for testing purposes only. Not required to run analysis.
# #* @get /
# #* @post /
# function(){return("alive")}
# 
# #* Runs STAGE test script
# #* @get /box-transfer-test-api
# #* @post /box-transfer-test-api
# function() {

  # Set parameters 
  report_name <- "gcp2box_test_report.pdf"
  bucket      <- "gs://test_analytics_team_bucket" 
  project     <- "nih-nci-dceg-connect-dev"  
  billing     <- project # Billing must be same as project
  
  # Simple query.
  query_rec <- "SELECT d_117249500 AS Age 
                FROM `nih-nci-dceg-connect-dev.FlatConnect.participants_JP` 
                WHERE Connect_ID IS NOT NULL"
  
  # BigQuery authorization. Should work smoothly on GCP without any inputs.
  bigrquery::bq_auth() 
  
  # Download some data
  rec_table <- bigrquery::bq_project_query(project, query_rec)
  rec_data  <- bigrquery::bq_table_download(rec_table, bigint = "integer64")
  ages      <- as.numeric(rec_data$Age)
  
  # Write a table to pdf as an example "report". 
  pdf(report_name)   # Open PDF
  hist(ages)         # Write histogram to PDF
  dev.off()          # Close PDF
  
  # TODO: Authenticate with Box and write report pdf to Box folder. 
  #       Must get token from GCP Cloud Secret Manager.
  #       Refs:
  #       (1) https://cloud.google.com/secret-manager/docs/create-secret-quickstart#secretmanager-quickstart-gcloud
  #       (2) https://cran.r-project.org/web/packages/googleCloudRunner/googleCloudRunner.pdf
  
  # Need OAuth app from GCP and permissions for thsi
  json_fid <- '/Users/petersjm/Desktop/gcp_info/oauth_info.json'
  app <- gargle::gargle_oauth_client_from_json(json_fid)
  gsecretR::gsecret_auth_config(app=app)
  gsecretR::gsecret_auth()
  secret <- gsecretR::get_secret_version(project_id=project, 
                                         secret_id='boxtoken')
  
  # Authenticate to Box
  # Documentation: https://r-box.github.io/boxr/articles/boxr-app-service.html#create
  # GitHub Issue: 
  
  # File from generate public/private key pair on Box app configuration tab
  token_fid <- 'Users/petersjm/Desktop/gcp_info/box_auth.json' # File from generate public/private key pair on Box app configuration tab
  boxr::box_auth(token_file=token_fid, token_text=secret)
  boxr::box_write(object=report_name, 
                  file_name=report_name, 
                  dir_id=198972272346, # GCP2BOX_test: 198972272346
                  description=NULL)
 
  # Authenticate with Google Storage and write report file to bucket
  scope <- c("https://www.googleapis.com/auth/cloud-platform")
  token <- gargle::token_fetch(scopes=scope)
  googleCloudStorageR::gcs_auth(token=token)
  googleCloudStorageR::gcs_upload(report_name, bucket=bucket, name=report_name) 
  
  # Return a string for for API testing purposes
  ret_str <- paste("All done. Check", bucket, "for", report_name)
  print(ret_str)
  return(ret_str) 
# }

