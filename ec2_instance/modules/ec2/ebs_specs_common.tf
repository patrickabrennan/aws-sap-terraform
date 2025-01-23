locals {

  common = {
    "hana" = [
      {
        identifier = "tmp",
        disk_nb    = 1,
        disk_size  = 50,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      },
      {
        identifier = "usrsap",
        disk_nb    = 2,
        disk_size  = 100,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      }
    ],
    "nw" = [
      {
        identifier = "tmp",
        disk_nb    = 1,
        disk_size  = 30,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      },
      {
        identifier = "usrsap",
        disk_nb    = 1,
        disk_size  = 60,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      },
      {
        identifier = "swap",
        disk_nb    = 1,
        disk_size  = 20,
        iops       = 3000,
        throughput = 125,
        disk_type  = "gp3"
      }
    ]
  }

}


