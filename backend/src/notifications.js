const {
  SQSClient,
  SendMessageCommand
} = require("@aws-sdk/client-sqs");

const sqs = new SQSClient({
  region: process.env.AWS_REGION
});

async function queueEmployeeCreated(employee) {
  const queueUrl = process.env.SQS_QUEUE_URL;

  if (!queueUrl) {
    console.log("SQS_QUEUE_URL is not configured; skipping email event.");
    return false;
  }

  await sqs.send(new SendMessageCommand({
    QueueUrl: queueUrl,
    MessageBody: JSON.stringify({
      eventType: "EmployeeCreated",
      employee: {
        id: employee.id,
        name: employee.name,
        email: employee.email,
        department: employee.department
      }
    })
  }));

  return true;
}

module.exports = { queueEmployeeCreated };
