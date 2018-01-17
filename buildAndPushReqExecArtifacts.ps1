$ErrorActionPreference = "Stop"

# Input parameters
$RES_REPO = "$($args[0])"
$ARCHITECTURE = "x86_64"
$OS = "WindowsServer_2016"
$ARTIFACTS_BUCKET = "s3://shippable-artifacts"
$VERSION = "master"

# reqExec
$REQ_EXEC_PATH = $(shipctl get_resource_state $RES_REPO)
$REQ_EXEC_PACKAGE_PATH = [System.IO.Path]::Combine($REQ_EXEC_PATH, "package", $ARCHITECTURE, $OS)

# Binaries
$REQ_EXEC_BINARY_DIR = Join-Path "$env:TEMP" "reqExec"
$REQ_EXEC_BINARY_ZIP = Join-Path "$env:TEMP" "reqExec-$VERSION-$ARCHITECTURE-$OS.zip"
$S3_BUCKET_BINARY_DIR = "$ARTIFACTS_BUCKET/reqExec/$VERSION/"

Function check_input() {
  if (-not $ARCHITECTURE) {
    Throw "Missing input parameter ARCHITECTURE"
  }

  if (-not $OS) {
    Throw "Missing input parameter OS"
  }

  if (-not $ARTIFACTS_BUCKET) {
    Throw "Missing input parameter ARTIFACTS_BUCKET"
  }
}

Function create_binaries_dir() {
  echo "Cleaning up $REQ_EXEC_BINARY_DIR..."

  if (Test-Path $REQ_EXEC_BINARY_DIR) {
    Remove-Item -Recurse -Force $REQ_EXEC_BINARY_DIR
  }

  New-Item -ItemType directory $REQ_EXEC_BINARY_DIR
}

Function build_reqExec() {
  pushd $REQ_EXEC_PATH
    echo "Packaging reqExec..."
    & $REQ_EXEC_PACKAGE_PATH\package.ps1

    # main.exe should be inside dist/main/ instead of dist/
    $bin_directory = ".\dist\main"
    New-Item -ItemType Directory -Force -Path $bin_directory
    Move-Item -Force .\dist\main.exe $bin_directory

    echo "Copying dist..."
    Copy-Item dist -Destination $REQ_EXEC_BINARY_DIR -Recurse
  popd
}

Function push_to_s3() {
  echo "Pushing to S3..."
  Compress-Archive -Path $REQ_EXEC_BINARY_DIR -DestinationPath $REQ_EXEC_BINARY_ZIP
  aws s3 cp --acl public-read "$REQ_EXEC_BINARY_ZIP" "$S3_BUCKET_BINARY_DIR"
}

check_input
create_binaries_dir
build_reqExec
push_to_s3
