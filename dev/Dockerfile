# Dockerfile

FROM rocker/tidyverse:latest
RUN install2.r plumber bigrquery boxr googleCloudStorageR devtools

# Install daniels Google Secret Manager R package using devtools 
RUN R -e "devtools::install_github('episphere/gsecretR')"

# Copy R code to directory in instance
COPY ["./test_api.r", "./test_api.r"]

# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('test_api.r'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
