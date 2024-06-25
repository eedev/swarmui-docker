# BUILD
FROM mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim AS build

ARG REPOSITORY="https://github.com/mcmonkeyprojects/SwarmUI.git"

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV APP_ROOT="/app"

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y git

WORKDIR ${APP_ROOT}

RUN git clone $REPOSITORY .

RUN dotnet build src/SwarmUI.csproj --configuration Release -o ./bin

# RUN
FROM mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim

ARG SWARMUI_USER_ID=1000
ARG SWARMUI_GROUP_ID=1000
ARG SWARMUI_DEV

ENV APP_ROOT="/app"
ENV NVIDIA_VISIBLE_DEVICES=all
ENV CLI_ARGS=""

RUN addgroup --gid $SWARMUI_GROUP_ID swarmui && \
    adduser --uid $SWARMUI_USER_ID --gid $SWARMUI_GROUP_ID --gecos "" --disabled-password swarmui

COPY --from=build ${APP_ROOT} ${APP_ROOT}

RUN mkdir -p ${APP_ROOT}/Data ${APP_ROOT}/dlbackend

RUN chown -R swarmui:swarmui ${APP_ROOT}

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    # Install python
    apt-get install -y git wget build-essential python3.11 python3.11-venv python3.11-dev \
    # Install dependencies for controlnet preprocessors
    libglib2.0-0 libgl1

WORKDIR ${APP_ROOT}

USER swarmui

RUN chmod +x ${APP_ROOT}/launchtools/comfy-install-linux.sh && \
    ${APP_ROOT}/launchtools/comfy-install-linux.sh

EXPOSE 7801

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh", "--launch_mode", "none", "--host", "0.0.0.0"]
