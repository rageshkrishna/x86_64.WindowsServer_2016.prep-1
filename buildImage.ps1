`$ErrorActionPreference = "Stop"

$CONTEXT = "$($args[0])"
$CURR_JOB = "$($args[1])"
$HUB_ORG = "drydock"
if ("$($args[2])") {
  $HUB_ORG = "$($args[2])"
}
$TAG_NAME = "master"

Function set_context() {
  $RES_REPO = "${CONTEXT}_repo"
  $RES_REPO_COMMIT = $(shipctl get_resource_version_key "$RES_REPO" "shaData.commitSha")
  $IMAGE_NAME = $CONTEXT.ToLower()
  $RES_IMAGE_OUT = "${CONTEXT}_img"
  $BLD_IMG = "${HUB_ORG}/${IMAGE_NAME}:${TAG_NAME}"

  echo "BUILD_NUMBER=$BUILD_NUMBER"
  echo "CONTEXT=$CONTEXT"
  echo "HUB_ORG=$HUB_ORG"
  echo "TAG_NAME=$TAG_NAME"

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REPO=$RES_REPO"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_COMMIT=$RES_REPO_COMMIT"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_IMAGE_OUT=$RES_IMAGE_OUT"
  echo "BLD_IMG=$BLD_IMG"
}

Function create_image() {
  pushd $(shipctl get_resource_state $RES_REPO)
    echo "Starting Docker build & push for $BLD_IMG"
    docker build -t="$BLD_IMG" --pull .
    echo "Pushing $BLD_IMG"
    docker push $BLD_IMG
    echo "Completed Docker build & push for $BLD_IMG"
  popd
}

Function create_out_state() {
  echo "Creating a state file for $RES_IMAGE_OUT"
  shipctl post_resource_state_multi "$RES_IMAGE_OUT" `
  "versionName=$TAG_NAME `
  IMG_REPO_COMMIT_SHA=$RES_REPO_COMMIT `
  BUILD_NUMBER=$BUILD_NUMBER"

  echo "Creating a state file for $CURR_JOB"
  shipctl post_resource_state_multi "$CURR_JOB" `
  "versionName=$TAG_NAME `
  IMG_REPO_COMMIT_SHA=$RES_REPO_COMMIT"
}

Function main() {
  set_context
  create_image
  create_out_state
}

main
`
