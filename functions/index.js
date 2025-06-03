/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const twilio = require("twilio");

const accountSid = functions.config().twilio.sid;
const authToken = functions.config().twilio.token;
const twilioNumber = functions.config().twilio.number;

const client = twilio(accountSid, authToken);

exports.sendFallAlert = functions.https.onRequest((req, res) => {
  const { to, message } = req.body;

  if (!to || !message) {
    return res.status(400).send("Faltan parámetros");
  }

  client.messages
    .create({
      body: message,
      to,
      from: twilioNumber,
    })
    .then(msg => res.status(200).send(`Mensaje enviado: ${msg.sid}`))
    .catch(err => res.status(500).send(`Error: ${err.message}`));
});

