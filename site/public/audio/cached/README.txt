This is where audio files will be stored when Sillyio fetches them. Per Twilio's design, files are
cached indefinitely but a HTTP request is still made for each Play verb to see if the file has changed.

All filenames are Base64 encoded forms of the URL.

If you're going to be doing a lot of Playing and Saying, this folder may get big. Make sure it doesn't
expend your disk space.