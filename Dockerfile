FROM postgres:12-alpine

WORKDIR /app

ADD setup.sh .
ADD sql ./sql
CMD [ "/bin/bash", "setup.sh" ]
