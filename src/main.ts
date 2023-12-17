const sourcePhoneNumber = process.env.SOURCE_PHONE_NUMBER;
const targetPhoneNumber = process.env.TARGET_PHONE_NUMBER;

const twilioUsername = process.env.TWILIO_USERNAME;
const twilioPassword = process.env.TWILIO_PASSWORD;

const bucketName = process.env.BUCKET_NAME;
const objectName = process.env.OBJECT_NAME;

import {ScheduledEvent} from "aws-lambda";

import {Twilio} from "twilio";
const twilio = new Twilio(twilioUsername, twilioPassword);

import S3 from "aws-sdk/clients/s3";
const s3 = new S3({});

export const entrypoint = async (_: ScheduledEvent): Promise<void> => {
  try {
    const params = {Bucket: bucketName, Key: objectName, Expires: 604800}; // => TODO: Use IAM user

    const url = s3.getSignedUrl("getObject", params);

    const msg = await twilio.messages.create({
      body: `Merry Christmas! ${url}`,
      from: `whatsapp:${sourcePhoneNumber}`,
      to:   `whatsapp:${targetPhoneNumber}`,
    });
    console.debug(msg.sid);
  }
  catch (err) {
    console.error(err);
    throw err;
  }
};
