FROM ubuntu:jammy-20230425

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y sudo locales openssl weston xwayland winpr-utils freerdp2-wayland x11-apps lxtask gnome-text-editor && \
    locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

ARG USER=testuser
ARG PASS=1234

RUN useradd -m $USER -p $(openssl passwd $PASS) && \
    usermod -aG sudo $USER && \
    chsh -s /bin/bash $USER

WORKDIR /home/$USER

RUN sudo -u $USER -g $USER -- winpr-makecert -rdp -path /home/$USER/.config && \
    sudo -u $USER -g $USER -- mkdir /tmp/.display && \
    sudo -u $USER -g $USER -- chmod 0700 /tmp/.display && \
    sudo -u $USER -g $USER -- mkdir /tmp/.X11-unix && \
    sudo -u $USER -g $USER -- chmod 1777 /tmp/.X11-unix

RUN echo "#!/bin/sh\n\
sudo -u $USER -g $USER -E -H -- weston --backend=rdp-backend.so --modules=xwayland.so --rdp-tls-cert=.config/buildkitsandbox.crt --rdp-tls-key=.config/buildkitsandbox.key --socket=wayland-0" > /startweston && chmod +x /startweston

ENV XDG_RUNTIME_DIR=/tmp/.display

EXPOSE 3389

CMD /startweston & bash