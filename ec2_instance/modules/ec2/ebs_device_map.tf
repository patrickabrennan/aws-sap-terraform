locals {

  device_name = {
    "data" : {
      "0" : "/dev/xvdf",
      "1" : "/dev/xvdg",
      "2" : "/dev/xvdi",
      "3" : "/dev/xvdj",
      "4" : "/dev/xvdk",
      "5" : "/dev/xvdl",
      "6" : "/dev/xvdm"
    },
    "log" : {
      "0" : "/dev/xvdn",
      "1" : "/dev/xvdq"
    },
    "backup" : {
      "0" : "/dev/xvdr"
    },
    "shared" : {
      "0" : "/dev/xvdp"
    },
    "tmp" : {
      "0" : "/dev/xvdb"
    },
    "usrsap" : {
      "0" : "/dev/xvdc",
      "1" : "/dev/xvds"
    },
    "swap" : {
      "0" : "/dev/xvdo"
    }
  }

  os_path_to_mount = {
    data : "/hana/data",
    log : "/hana/log",
    backup : "/hana/backup",
    shared : "/hana/shared",
    tmp : "/tmp",
    usrsap : "/usr/sap",
    swap : "swap"
  }

}
