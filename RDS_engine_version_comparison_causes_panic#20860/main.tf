terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure AWS provider
provider "aws" {
    region = "ap-northeast-1"
}



resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"

}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "tf-acc-rds-cluster-name-prefix-a"
  }
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "tf-acc-rds-cluster-name-prefix-b"
  }
}

resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "test"
  subnet_ids = [aws_subnet.a.id, aws_subnet.b.id]
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
resource "aws_security_group" "staging-db" {
  name = "hogehoge"
  vpc_id      = aws_vpc.test.id
}


resource "aws_rds_cluster" "staging-aurora-cluster" {
  port                 = 3306
  engine               = "aurora-mysql"
  engine_mode          = "serverless"
  engine_version       = "5.7.mysql_aurora.2.07.2"

  master_username        = "root"
  master_password        = "rootPassWordMustBe#"
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = [aws_security_group.staging-db.id]

  skip_final_snapshot     = true
  apply_immediately       = true
  backup_retention_period = 5 # days
  deletion_protection     = false

  scaling_configuration {
    auto_pause               = true
    min_capacity             = 1
    max_capacity             = 16
    seconds_until_auto_pause = 300
    timeout_action           = "RollbackCapacityChange"
  }
}
