var uploadList = {
  // view callback
  changed: function(){},
  pendingFiles: [],
  uploading: false,
  addFiles: function(newFiles) {
    for (var i = 0; i < newFiles.length; i += 1) {
      this.pendingFiles.push(newFiles[i]);
    }
    if(!this.uploading) this.startUpload();
  },
  startUpload: function() {
    this.uploading = true;
    // TODO: we already have a request queue somewhere - combine!
    whilst(getNextFile, uploadFile.start, done);

    function getNextFile() {
      return uploadFile.setFile(uploadList.pendingFiles.shift());
    }

    function done() {
      uploadList.uploading = false
    };
  }
}
