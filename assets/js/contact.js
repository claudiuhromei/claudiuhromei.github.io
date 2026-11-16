// Reveals the obfuscated email address in the author sidebar (see _includes/author-profile-custom-links.html).
(function (root) {
  "use strict";

  function reverse(text) {
    return text.split("").reverse().join("");
  }

  // Builds the address from its two reversed halves.
  function decodeAddress(userReversed, domainReversed) {
    return reverse(userReversed) + String.fromCharCode(64) + reverse(domainReversed);
  }

  function reveal(button) {
    var address = decodeAddress(button.dataset.user, button.dataset.domain);
    var label = button.querySelector(".label") || button;
    label.textContent = address;
    root.location.href = ["mail", "to:"].join("") + address;
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = { decodeAddress: decodeAddress };
    return;
  }

  root.document.addEventListener("click", function (event) {
    var button = event.target.closest(".js-contact");
    if (button) {
      event.preventDefault();
      reveal(button);
    }
  });
})(typeof window !== "undefined" ? window : this);
