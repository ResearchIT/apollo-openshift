#!/usr/bin/env bash
cd /opt/app-root/src/ && \
	# note that clean-all does more than remove the target directory files (which it does not do in its entirety)
    ./apollo clean-all && rm -rf target/* && ./apollo deploy && \
    cp /opt/app-root/src/target/apollo*.war /tmp/apollo.war && \
	# here we save the tools directory
	# So we can remove ~1.6 GB of cruft from the image. Ignore errors because cannot remove parent dir /opt/app-root/src/
    rm -rf /opt/app-root/src/ || true && \
	# Before moving back into a standardized location (that we have write access to)
	mv /tmp/apollo.war /opt/app-root/apollo.war

