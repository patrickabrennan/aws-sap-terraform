locals {

  hana_data_specs = {
    "x2iedn.xlarge" = {
      "gp2" = [{
        identifier = "data",
        disk_nb    = 3,
        disk_size  = 225,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "data",
        disk_nb    = 2,
        disk_size  = 350,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      }],
      "io1" = [{
        identifier = "data",
        disk_nb    = 2,
        disk_size  = 300,
        iops       = 2000,
        disk_type  = "io1"
      }],
      "io2" = [{
        identifier = "data",
        disk_nb    = 2,
        disk_size  = 300,
        iops       = 2000,
        disk_type  = "io2"
      }]
    },
    "r5.8xlarge" = {
      "gp2" = [{
        identifier = "data",
        disk_nb    = 3,
        disk_size  = 225,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "data",
        disk_nb    = 2,
        disk_size  = 320,
        iops       = 7500,
        throughput = 500,
        disk_type  = "gp3"
      }],
      "io1" = [{
        identifier = "data",
        disk_nb    = 1,
        disk_size  = 300,
        iops       = 7500,
        disk_type  = "io1"
      }],
      "io2" = [{
        identifier = "data",
        disk_nb    = 1,
        disk_size  = 350,
        iops       = 7500,
        disk_type  = "io2"
      }]
    },
    "r5.4xlarge" = {
      "gp2" = [{
        identifier = "data",
        disk_nb    = 3,
        disk_size  = 225,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "data",
        disk_nb    = 2,
        disk_size  = 160,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      }],
      "io1" = [{
        identifier = "data",
        disk_nb    = 1,
        disk_size  = 300,
        iops       = 2000,
        disk_type  = "io1"
      }],
      "io2" = [{
        identifier = "data",
        disk_nb    = 1,
        disk_size  = 300,
        iops       = 2000,
        disk_type  = "io2"
      }]
    }
  }

  hana_logs_specs = {
    "x2iedn.xlarge" = {
      "gp2" = [{
        identifier = "log",
        disk_nb    = 2,
        disk_size  = 256,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "log",
        disk_nb    = 2,
        disk_size  = 300,
        iops       = 3000,
        throughput = 250,
        disk_type  = "gp3"
      }],
      "io1" = [{
        identifier = "log",
        disk_nb    = 2,
        disk_size  = 300,
        iops       = 2000,
        disk_type  = "io1"
      }],
      "io2" = [{
        identifier = "log",
        disk_nb    = 2,
        disk_size  = 300,
        iops       = 2000,
        disk_type  = "io2"
      }]
    },
    "r5.8xlarge" = {
      "gp2" = [{
        identifier = "log",
        disk_nb    = 2,
        disk_size  = 300,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "log",
        disk_nb    = 1,
        disk_size  = 128,
        iops       = 3000,
        throughput = 300,
        disk_type  = "gp3"
      }],
      "io1" = [{
        identifier = "log",
        disk_nb    = 1,
        disk_size  = 260,
        iops       = 2000,
        disk_type  = "io1"
      }],
      "io2" = [{
        identifier = "log",
        disk_nb    = 1,
        disk_size  = 260,
        iops       = 2000,
        disk_type  = "io2"
      }]
    },
    "r5.4xlarge" = {
      "gp2" = [{
        identifier = "log",
        disk_nb    = 2,
        disk_size  = 175,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "log",
        disk_nb    = 1,
        disk_size  = 64,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      }],
      "io1" = [{
        identifier = "log",
        disk_nb    = 1,
        disk_size  = 260,
        iops       = 1000,
        disk_type  = "io1"
      }],
      "io2" = [{
        identifier = "log",
        disk_nb    = 1,
        disk_size  = 260,
        iops       = 1000,
        disk_type  = "io2"
      }]
    }
  }


  hana_backup_specs = {
    "x2iedn.xlarge" = {
      "gp3" = [{
        identifier = "backup",
        disk_nb    = 1,
        disk_size  = 512,
        iops       = 4500,
        throughput = 750,
        disk_type  = "gp3"
      }],
      "st1" = [{
        identifier = "backup",
        disk_nb    = 1,
        disk_size  = 512,
        iops       = 4500,
        throughput = 750,
        disk_type  = "st1"
      }]
    },
    "r5.8xlarge" = {
      "gp3" = [{
        identifier = "backup",
        disk_nb    = 1,
        disk_size  = 512,
        iops       = 4500,
        throughput = 750,
        disk_type  = "gp3"
      }],
      "st1" = [{
        identifier = "backup",
        disk_nb    = 1,
        disk_size  = 512
        disk_type  = "st1"
      }]
    },
    "r5.4xlarge" = {
      "gp3" = [{
        identifier = "backup",
        disk_nb    = 1,
        disk_size  = 256,
        iops       = 3000,
        throughput = 250,
        disk_type  = "gp3"
      }],
      "st1" = [{
        identifier = "backup",
        disk_nb    = 1,
        disk_size  = 300
        disk_type  = "st1"
      }]
    }
  }


  hana_shared_specs = {
    "x2iedn.xlarge" = {
      "gp2" = [{
        identifier = "shared",
        disk_nb    = 1,
        disk_size  = 512,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "shared",
        disk_nb    = 1,
        disk_size  = 512,
        iops       = 4500,
        throughput = 750,
        disk_type  = "gp3"
      }]
    },
    "r5.8xlarge" = {
      "gp2" = [{
        identifier = "shared",
        disk_nb    = 1,
        disk_size  = 300,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "shared",
        disk_nb    = 1,
        disk_size  = 300,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      }]
    },
    "r5.4xlarge" = {
      "gp2" = [{
        identifier = "shared",
        disk_nb    = 1,
        disk_size  = 300,
        disk_type  = "gp2"
      }],
      "gp3" = [{
        identifier = "shared",
        disk_nb    = 1,
        disk_size  = 300,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      }]
    }
  }
}


