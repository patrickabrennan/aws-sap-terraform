efs_to_create = {
  "D01-sapmnt" = {
    access_point_info = {
      posix_user = {
        gid = 5001,
        uid = 3001
      },
      root_directory = {
        creation_info = {
          owner_gid   = 5001,
          owner_uid   = 3001,
          permissions = 0775
        },
        path : "/",
      }
    }
   }
  #},
  #"D01-trans" = {
  #  access_point_info = {
  #    posix_user = {
  #      gid = 5001,
  #      uid = 3001
  #    },
  #    root_directory = {
  #      creation_info = {
  #        owner_gid   = 5001,
  #        owner_uid   = 3001,
  #        permissions = 0775
  #      },
  #      path : "/",
  #    }
  #  }
  #},
  #"D02-sapmnt" = {
  #  access_point_info = {
  #    posix_user = {
  #      gid = 5001,
  #      uid = 3001
  #    },
  #    root_directory = {
  #      creation_info = {
  #        owner_gid   = 5001,
  #        owner_uid   = 3001,
  #        permissions = 0775
  #      },
  #      path : "/",
  #    }
  #  }
  #},
  #"D02-trans" = {
  #  access_point_info = {
  #    posix_user = {
  #      gid = 5001,
  #      uid = 3001
  #    },
  #    root_directory = {
  #      creation_info = {
  #        owner_gid   = 5001,
  #        owner_uid   = 3001,
  #        permissions = 0775
  #      },
  #      path : "/",
  #    }
  #  }
  #}
}

#added the following on 8/21/2025"
keys_to_create = {
  "ebs" = {
    alias_name = "kms-alias-ebs"
    enable_key_rotation = true
  }
  "efs"        = {}
  "cloudwatch" = {}
  "s3"         = {}
}

