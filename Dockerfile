FROM ghcr.io/greenroom-robotics/ros_builder:iron-latest

# Create the package_manifests by deleting everything other than package.xml
WORKDIR /package_manifests
COPY ./ ./
RUN sudo chown ros:ros .
RUN sudo find . -regextype egrep -not -regex '.*/(package\.xml)$' -type f -delete
RUN sudo find . -type d -empty -delete

FROM ghcr.io/greenroom-robotics/ros_builder:iron-latest

ARG API_TOKEN_GITHUB
ARG PACKAGE_NAME
ARG PLATFORM_MODULE="platform_module"

LABEL org.opencontainers.image.source=https://github.com/Greenroom-Robotics/${PLATFORM_MODULE}

ENV PLATFORM_MODULE=$PLATFORM_MODULE

RUN sudo mkdir /opt/greenroom && sudo chown ros:ros /opt/greenroom
RUN --mount=type=cache,target=/home/ros/.cache/pip,sharing=locked \
  sudo chown -R ros:ros /home/ros/.cache/pip
RUN pip install git+https://github.com/Greenroom-Robotics/platform_cli.git@main

WORKDIR /home/package_manifests
RUN platform pkg setup
COPY --from=0 /package_manifests .
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  platform pkg install-deps --package=${PACKAGE_NAME}

WORKDIR /home/ros/${PLATFORM_MODULE}

COPY ./ ./
RUN sudo chown -R ros:ros /home/ros/${PLATFORM_MODULE}
# RUN --mount=type=cache,target=/home/ros/.cache/pip,sharing=locked \
#   platform poetry install
# RUN source ${ROS_OVERLAY}/setup.sh && platform ros build --package=${PACKAGE_NAME}
# RUN --mount=type=cache,target=/home/ros/.cache/pip,sharing=locked \
#   platform ros install_poetry_deps

# ENV ROS_OVERLAY /opt/greenroom/${PLATFORM_MODULE}
# RUN echo 'source ${ROS_OVERLAY}/setup.sh' >> ~/.profile

CMD tail -f /dev/null