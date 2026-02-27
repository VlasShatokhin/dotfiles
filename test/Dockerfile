FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends zsh git curl jq ca-certificates && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/zsh tester
USER tester
WORKDIR /home/tester
RUN mkdir -p /home/tester/bin
COPY --chown=tester:tester test/mock-brew /home/tester/bin/brew
ENV PATH="/home/tester/bin:$PATH"
COPY --chown=tester:tester . /home/tester/dotfiles/
ENTRYPOINT ["/bin/zsh"]
