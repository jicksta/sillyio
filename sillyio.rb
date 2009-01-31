# This must return a String which uniquely identifies this. The TwiML spec requires it start with "AC" and be 34 characters long.

applications {
  "http://www.twilio.com/resources/code/demos/helloworld/index.xml"
}

store_audio_files_in "tmp"

account_guid {
  "AC_SILLYIO_#{Process.uid}_#{MD5.md5(`hostname`)}"[0,34]
}