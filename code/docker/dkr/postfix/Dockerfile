FROM debian:bullseye

# Set environment variables
ENV MAIL_DOMAIN example.com
ENV MAIL_HOSTNAME mail.example.com
ENV MAIL_USER user@example.com
ENV MAIL_PASSWORD password

# Install Postfix and other required packages
RUN apt-get update && apt-get install -y postfix mailutils

# Configure Postfix
RUN echo "postfix postfix/mailname string $MAIL_DOMAIN" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
RUN echo "postfix postfix/mynetworks string 0.0.0.0/0" | debconf-set-selections
RUN echo "postfix postfix/mailbox_limit string 0" | debconf-set-selections
RUN echo "postfix postfix/relayhost string [$MAIL_HOSTNAME]:587" | debconf-set-selections
RUN echo "postfix postfix/smtp_sasl_auth_enable string yes" | debconf-set-selections
RUN echo "postfix postfix/smtp_sasl_password_maps string hash:/etc/postfix/sasl_passwd" | debconf-set-selections
RUN echo "postfix postfix/smtp_sasl_security_options string noanonymous" | debconf-set-selections

# Create sasl_passwd file with credentials
RUN echo "[$MAIL_HOSTNAME]:587 $MAIL_USER:$MAIL_PASSWORD" > /etc/postfix/sasl_passwd
RUN postmap /etc/postfix/sasl_passwd
RUN chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
RUN chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

# Start Postfix service
CMD ["service", "postfix", "start"]
