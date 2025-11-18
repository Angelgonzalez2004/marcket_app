/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {onCall} = require("firebase-functions/v2/https"); // Import onCall from v2
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin"); // Import firebase-admin
const mercadopago = require("mercadopago"); // Import mercadopago SDK

admin.initializeApp(); // Initialize firebase-admin

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

const {onValueCreated} = require("firebase-functions/v2/database");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.updateProductRating = onValueCreated("reviews/{productId}/{reviewId}", async (event) => {
  const { productId } = event.params;
  const reviewData = event.data.val();
  const sellerId = reviewData.sellerId;

  if (!sellerId) {
    logger.error(`Review ${event.params.reviewId} for product ${productId} is missing a sellerId.`);
    return null;
  }

  const reviewsRef = admin.database().ref(`reviews/${productId}`);
  const snapshot = await reviewsRef.once("value");
  const reviews = snapshot.val();

  if (!reviews) {
    return null;
  }

  const reviewValues = Object.values(reviews);
  const reviewCount = reviewValues.length;
  const totalRating = reviewValues.reduce((acc, review) => acc + review.rating, 0);
  const averageRating = totalRating / reviewCount;

  const productRef = admin.database().ref(`products/${sellerId}/${productId}`);
  
  logger.info(`Updating product ${productId} with new rating:`, {
    averageRating: averageRating.toFixed(2),
    reviewCount: reviewCount,
  });

  return productRef.update({
    averageRating: parseFloat(averageRating.toFixed(2)),
    reviewCount: reviewCount,
  });
});

exports.createPaymentPreference = onCall(async (request) => {
  logger.info("createPaymentPreference called", {structuredData: true});

  const { cartItems, userId } = request.data;

  if (!cartItems || !Array.isArray(cartItems) || cartItems.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with an array of cartItems.'
    );
  }
  if (!userId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with a userId.'
    );
  }

  // Get Mercado Pago Access Token from environment config
  const accessToken = functions.config().mercadopago.accesstoken;
  if (!accessToken) {
    throw new functions.https.HttpsError(
      'internal',
      'Mercado Pago Access Token not configured.'
    );
  }
  mercadopago.configure({
    access_token: accessToken,
  });

  const items = cartItems.map(item => ({
    title: item.name,
    unit_price: item.price,
    quantity: item.quantity,
    currency_id: "MXN", // Assuming Mexican Pesos
    picture_url: item.imageUrl,
    description: item.description || item.name,
  }));

  let payerEmail = "anonymous@example.com"; // Default email
  try {
    const userRecord = await admin.auth().getUser(userId);
    payerEmail = userRecord.email || payerEmail;
  } catch (error) {
    logger.warn(`Could not fetch email for user ${userId}: ${error.message}`);
  }

  const preference = {
    items: items,
    payer: {
      email: payerEmail,
    },
    external_reference: userId, // Use userId to link payment to user
    notification_url: "https://receivemercadopagowebhook-vf47anzufq-uc.a.run.app",
    back_urls: {
      success: "https://marcketapp-25ac2.web.app/payment/success",
      pending: "https://marcketapp-25ac2.web.app/payment/pending",
      failure: "https://marcketapp-25ac2.web.app/payment/failure",
    },
    auto_return: "approved",
  };

  try {
    const response = await mercadopago.preferences.create(preference);
    logger.info("Mercado Pago preference created", { preferenceId: response.body.id });
    return { preferenceId: response.body.id };
  } catch (error) {
    logger.error("Error creating Mercado Pago preference:", error);
    throw new functions.https.HttpsError(
      'internal',
      'Unable to create Mercado Pago preference.',
      error.message
    );
  }
});

exports.receiveMercadoPagoWebhook = onRequest(async (request, response) => {
  logger.info("Mercado Pago Webhook received", { query: request.query, body: request.body });

  const { topic, id } = request.query;

  if (topic === 'payment' && id) {
    // Get Mercado Pago Access Token from environment config
    const accessToken = functions.config().mercadopago.accesstoken;
    if (!accessToken) {
      logger.error("Mercado Pago Access Token not configured for webhook.");
      response.status(500).send("Mercado Pago Access Token not configured.");
      return;
    }
    mercadopago.configure({
      access_token: accessToken,
    });

    try {
      const payment = await mercadopago.payment.get(id);
      logger.info("Mercado Pago Payment details", { paymentStatus: payment.body.status, paymentId: payment.body.id });

      if (payment.body.status === 'approved') {
        const orderId = payment.body.external_reference; // Assuming external_reference is the orderId
        if (orderId) {
          // Update order status in Firebase Realtime Database
          await admin.database().ref(`orders/${orderId}`).update({
            status: 'preparing', // Changed from 'approved' to 'preparing'
            paymentId: payment.body.id,
            paymentMethod: payment.body.payment_type_id,
          });
          logger.info(`Order ${orderId} updated to preparing.`);
        } else {
          logger.warn("No orderId found in external_reference for approved payment.");
        }
      } else {
        logger.info(`Payment ${id} is not approved. Status: ${payment.body.status}`);
      }

      response.status(200).send("Webhook received and processed.");
    } catch (error) {
      logger.error("Error processing Mercado Pago webhook:", error);
      response.status(500).send("Error processing webhook.");
    }
  } else {
    logger.warn("Webhook received with invalid topic or ID.", { topic, id });
    response.status(400).send("Invalid webhook request.");
  }
});

