FROM amazon/aws-cli:2.2.44

WORKDIR /app

COPY . .

RUN apk add --no-cache bash

CMD ["bash", "deploy.sh"]
