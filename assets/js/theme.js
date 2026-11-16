// Light/dark theme: follows the OS by default; the toggle button stores an explicit choice.
// Loaded in <head> right after the dark stylesheet so the stored choice is applied before first paint.
// The dark skin is a second stylesheet whose `media` attribute decides whether it applies.
(function (root) {
  "use strict";

  var STORAGE_KEY = "theme";
  var SYSTEM_DARK_QUERY = "(prefers-color-scheme: dark)";

  function isTheme(value) {
    return value === "light" || value === "dark";
  }

  // Value of the dark stylesheet's `media` attribute for a stored preference (or none).
  function darkStylesheetMedia(preference) {
    if (preference === "dark") {
      return "all";
    }
    return preference === "light" ? "not all" : SYSTEM_DARK_QUERY;
  }

  // Theme actually shown: the stored preference if valid, otherwise the OS setting.
  function effectiveTheme(preference, systemPrefersDark) {
    if (isTheme(preference)) {
      return preference;
    }
    return systemPrefersDark ? "dark" : "light";
  }

  function oppositeTheme(theme) {
    return theme === "dark" ? "light" : "dark";
  }

  function toggleLabel(theme) {
    return "Switch to " + oppositeTheme(theme) + " theme";
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = {
      darkStylesheetMedia: darkStylesheetMedia,
      effectiveTheme: effectiveTheme,
      oppositeTheme: oppositeTheme,
      toggleLabel: toggleLabel
    };
    return;
  }

  var document = root.document;
  var systemDark = root.matchMedia(SYSTEM_DARK_QUERY);

  // Storage can be unavailable (private mode, blocked site data): the theme then follows the OS.
  function readPreference() {
    try {
      return root.localStorage.getItem(STORAGE_KEY);
    } catch (error) {
      return null;
    }
  }

  function storePreference(theme) {
    try {
      root.localStorage.setItem(STORAGE_KEY, theme);
    } catch (error) {
      // The choice still applies to the current page.
    }
  }

  function apply(preference) {
    var stylesheet = document.getElementById("dark-stylesheet");
    var colorScheme = document.querySelector('meta[name="color-scheme"]');
    if (stylesheet) {
      stylesheet.media = darkStylesheetMedia(preference);
    }
    if (colorScheme) {
      colorScheme.content = isTheme(preference) ? preference : "light dark";
    }
  }

  function updateButton(button, theme) {
    var icon = button.querySelector("i");
    var label = toggleLabel(theme);
    button.setAttribute("aria-label", label);
    button.title = label;
    if (icon) {
      icon.classList.toggle("fa-sun", theme === "dark");
      icon.classList.toggle("fa-moon", theme === "light");
    }
  }

  var preference = readPreference();
  apply(preference);

  document.addEventListener("DOMContentLoaded", function () {
    var button = document.querySelector(".js-theme-toggle");
    if (!button) {
      return;
    }

    button.hidden = false;
    updateButton(button, effectiveTheme(preference, systemDark.matches));

    button.addEventListener("click", function () {
      preference = oppositeTheme(effectiveTheme(preference, systemDark.matches));
      storePreference(preference);
      apply(preference);
      updateButton(button, preference);
    });

    systemDark.addEventListener("change", function () {
      updateButton(button, effectiveTheme(preference, systemDark.matches));
    });
  });
})(typeof window !== "undefined" ? window : this);
