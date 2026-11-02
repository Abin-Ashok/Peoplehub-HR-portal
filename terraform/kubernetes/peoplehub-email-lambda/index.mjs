import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";

const ses = new SESClient({
  region: process.env.AWS_REGION,
});

export const handler = async (event) => {
  const batchItemFailures = [];

  for (const record of event.Records ?? []) {
    try {
      const message = JSON.parse(record.body);

      const employee = message.employee;
      const toEmail = employee?.email || message.toEmail;
      const employeeName =
        employee?.name || message.employeeName || "there";

      if (!toEmail) {
        throw new Error("Missing employee email in SQS message");
      }

      const subject = employee
        ? "Welcome to PeopleHub!"
        : "PeopleHub notification test";

      const body = employee
        ? `Hi ${employeeName},

Welcome to PeopleHub!

Your employee account has been successfully created. We're happy to have you on board!

Your employee details:
Name: ${employee.name || employeeName}
Email: ${employee.email || toEmail}
Department: ${employee.department || "Not specified"}

We wish you a great journey with PeopleHub!

Best regards,
The PeopleHub Team`
        : `Hi ${employeeName},

Welcome to PeopleHub!

${message.details || "Your PeopleHub notification test was successful."}

Best regards,
The PeopleHub Team`;

      await ses.send(
        new SendEmailCommand({
          Source: process.env.SES_FROM_EMAIL,
          Destination: {
            ToAddresses: [toEmail],
          },
          Message: {
            Subject: {
              Data: subject,
              Charset: "UTF-8",
            },
            Body: {
              Text: {
                Data: body,
                Charset: "UTF-8",
              },
            },
          },
        })
      );

      console.log(`Email sent successfully to ${toEmail}`);
    } catch (error) {
      console.error("Failed to process SQS message:", error);
      batchItemFailures.push({
        itemIdentifier: record.messageId,
      });
    }
  }

  return { batchItemFailures };
};
