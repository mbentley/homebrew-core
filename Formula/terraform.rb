class Terraform < Formula
  desc "Tool to build, change, and version infrastructure"
  homepage "https://www.terraform.io/"
  url "https://github.com/hashicorp/terraform/archive/v0.9.1.tar.gz"
  sha256 "af8402ce84b85a16cfac3796c1f30f229a0d0e93585c6c618af2f25aae067e65"
  head "https://github.com/hashicorp/terraform.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "163c6cf4610131caf9e15c6dff117d68425bdcc35dedb00d4069bf490607cb4e" => :sierra
    sha256 "a253c2ee5889326787a780d58564d74517e3612a6bcea2ae48ffd7a5bad2c638" => :el_capitan
    sha256 "c09b0675ba6cf2e3dbcc79a89181808a38ac40e1917b8c13c22e008d94691904" => :yosemite
  end

  depends_on "go" => :build

  conflicts_with "tfenv", :because => "tfenv symlinks terraform binaries"

  # vet error (please remove after next version release)
  # upstream issue: https://github.com/hashicorp/terraform/pull/12839
  patch do
    url "https://github.com/hashicorp/terraform/commit/bc4a3d62a59dc14c11a8546cc4e7e32ec7553fab.patch"
    sha256 "ac312a0cc46833a45ef51d56961bdc7c7d60cb8c709ee305f476e4b68e8685e5"
  end

  def install
    dir = buildpath/"src/github.com/hashicorp/terraform"
    dir.install buildpath.children - [buildpath/".brew_home"]

    ENV["GOPATH"] = buildpath
    ENV.prepend_create_path "PATH", buildpath/"bin"

    cd dir do
      # v0.6.12 - source contains tests which fail if these environment variables are set locally.
      ENV.delete "AWS_ACCESS_KEY"
      ENV.delete "AWS_SECRET_KEY"

      arch = MacOS.prefer_64_bit? ? "amd64" : "386"
      ENV["XC_OS"] = "darwin"
      ENV["XC_ARCH"] = arch
      system "make", "test", "vet", "bin"

      bin.install "pkg/darwin_#{arch}/terraform"
      zsh_completion.install "contrib/zsh-completion/_terraform"
      prefix.install_metafiles
    end
  end

  test do
    minimal = testpath/"minimal.tf"
    minimal.write <<-EOS.undent
      variable "aws_region" {
          default = "us-west-2"
      }

      variable "aws_amis" {
          default = {
              eu-west-1 = "ami-b1cf19c6"
              us-east-1 = "ami-de7ab6b6"
              us-west-1 = "ami-3f75767a"
              us-west-2 = "ami-21f78e11"
          }
      }

      # Specify the provider and access details
      provider "aws" {
          access_key = "this_is_a_fake_access"
          secret_key = "this_is_a_fake_secret"
          region = "${var.aws_region}"
      }

      resource "aws_instance" "web" {
        instance_type = "m1.small"
        ami = "${lookup(var.aws_amis, var.aws_region)}"
        count = 4
      }
    EOS
    system "#{bin}/terraform", "graph", testpath
  end
end
