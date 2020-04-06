install.packages('GetHFData', repos = "http://cran.us.r-project.org")

library(GetHFData)

df = ghfd_get_ftp_contents()
data_dir = 'data/ftp_files'
for (row in 1:nrow(df)){
    my.ftp = as.character(df[row, 'link'])
    file = as.character(df[row, 'files'])
    out.file = paste(data_dir, file, sep='/')
    if (!file %in% list.files(data_dir)){
        ghfd_download_file(my.ftp, out.file)
    }
}