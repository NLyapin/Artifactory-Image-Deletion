#!/bin/bash
set -euo pipefail

# Настройки
#REPO=example
NUM_IMAGES=10
JF_CLI_CONTAINER=jf-cli
#SERVER_ID=example

# --- Часть 1: создание цепочки образов ---
PREV_IMAGE="alpine:3.18"

for i in $(seq 0 $NUM_IMAGES); do
    IMAGE_NAME="$REPO/deletion-image-$i"
    FILE_NAME="tmp$i"

    if [ "$i" -eq 0 ]; then
        # первый образ без файла
        docker build -t $IMAGE_NAME - <<EOF
FROM $PREV_IMAGE
EOF
    else
        docker build -t $IMAGE_NAME - <<EOF
FROM $PREV_IMAGE
RUN touch /$FILE_NAME
EOF
    fi

    docker push $IMAGE_NAME
    PREV_IMAGE="$IMAGE_NAME"
done

# --- Часть 2: удаление всех образов кроме deletion-image-0 через jf CLI ---
for i in $(seq 1 $NUM_IMAGES); do
    docker exec -it $JF_CLI_CONTAINER jf rt del "$REPO/deletion-image-$i/**" \
        --server-id=$SERVER_ID $INSECURE_TLS --quiet
done

echo "Удаление завершено, остался только deletion-image-0."

# 4. Заходим в контейнер deletion-image-0 для проверки
CONTAINER_ID=$(docker run -d -it $IMAGE_BASE /bin/sh)
echo "Заходим в контейнер $CONTAINER_ID"
docker exec -it $CONTAINER_ID /bin/sh