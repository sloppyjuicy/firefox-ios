// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// /* eslint-disable mozilla/balanced-listeners, no-undef */
import FormAutofillHelper from "resource://gre/modules/shared/EntryFile.sys.mjs";
import FormAutofillExtras from "Assets/CC_Script/FormAutofillExtras.ios.mjs";

// Define supported message types.
const messageTypes = {
  FILL_CREDIT_CARD_FORM: "fill-credit-card-form",
  CAPTURE_CREDIT_CARD_FORM: "capture-credit-card-form",
  FILL_ADDRESS_FORM: "fill-address-form",
  CAPTURE_ADDRESS_FORM: "capture-address-form",
};

const transformers = {
  forward: (payload) => payload,
};

// Generic Helper function to send a message back to swift.
const sendMessage =
  (messageHandler) =>
  (type, transformer = transformers.forward) =>
  (payload) =>
    messageHandler?.postMessage({
      type,
      payload: transformer(payload),
    });

// This should be handled by CreditCardRecord.normalizeFields
// TODO(issam, FXCM-810): Revisit data representation for address and credit card as this has caused a lot of bugs
// for now we explicitly define the data shape we expect and defaults.
const expectedCreditCardPayloadShape = {
  "cc-name": "",
  "cc-exp-month": "",
  "cc-exp-year": "",
};

// This should be handled by normalizeFields
// TODO(issam, FXCM-810): Revisit data representation for address and credit card as this has caused a lot of bugs
// for now we explicitly define the data shape we expect and defaults.
const expectedAddressPayloadShape = {
  "address-level1": "",
  organization: "",
  country: "",
  "address-level2": "",
  "address-level3": "",
  email: "",
  "street-address": "",
  name: "",
  postalCode: "",
  tel: "",
};

const normalizePayload = (expectedPayloadShape) => (payload) => {
  const items = Array.isArray(payload) ? payload : [payload];
  const normalizedPaylod = {
    ...expectedPayloadShape,
    ...(items?.[0] ?? {}),
  };

  return Object.entries(normalizedPaylod).reduce(
    (acc, [key, val]) => ({
      ...acc,
      [key]: String(val),
    }),
    {}
  );
};

const creditCardSendMessage = sendMessage(
  window.webkit.messageHandlers.creditCardFormMessageHandler
);

const addressSendMessage = sendMessage(
  window.webkit.messageHandlers.addressFormMessageHandler
);

// Note: We expect all values to be string based
const sendCaptureCreditCardFormMessage = creditCardSendMessage(
  messageTypes.CAPTURE_CREDIT_CARD_FORM,
  normalizePayload(expectedCreditCardPayloadShape)
);

const sendFillCreditCardFormMessage = creditCardSendMessage(
  messageTypes.FILL_CREDIT_CARD_FORM,
  normalizePayload(expectedCreditCardPayloadShape)
);

const sendFillAddressFormMessage = addressSendMessage(
  messageTypes.FILL_ADDRESS_FORM,
  normalizePayload(expectedAddressPayloadShape)
);

// TODO: Define this method in Address Autofill Phase 3
const sendCaptureAddressFormMessage = addressSendMessage(
  messageTypes.CAPTURE_ADDRESS_FORM,
  normalizePayload(expectedAddressPayloadShape)
);

// Create a FormAutofillHelper object and expose it to the window object.
// The FormAutofillHelper should:
// - expose a method .fillFormFields(payload) that can be called from swift to fill in data.
// - call creditCard.submit(payload) when a credit card form submission is detected.
// - call creditCard.autofill(payload) when a credit card form is detected.
// - call address.submit(payload) when a address form submission is detected.
// - call address.autofill(payload) when a address form is detected.
// The implementation file can be changed in Client/Assets/CC_Script/Overrides.ios.js
Object.defineProperty(window.__firefox__, "FormAutofillHelper", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(
    new FormAutofillHelper({
      creditCard: {
        submit: sendCaptureCreditCardFormMessage,
        autofill: sendFillCreditCardFormMessage,
      },
      address: {
        submit: sendCaptureAddressFormMessage,
        autofill: sendFillAddressFormMessage,
      },
    })
  ),
});

// Create a FormAutofillExtras object and expose it to the window object.
// FormAutofillExtras class contains methods to focus next and previous input fields.
Object.defineProperty(window.__firefox__, "FormAutofillExtras", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(new FormAutofillExtras()),
});
