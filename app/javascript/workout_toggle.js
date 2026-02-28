function toggleWorkoutCard(button) {
  const card = button.closest(".workout-log-card");
  if (!card) return;

  const body = card.querySelector(".workout-body") || card.querySelector(".workout-log-card__body");
  if (!body) return;

  const fade = card.querySelector(".workout-fade");
  const collapsedHeight = body.dataset.collapsedHeight || "220px";
  const usesInlineMaxHeight = body.classList.contains("workout-body");

  if (usesInlineMaxHeight) {
    if (body.style.maxHeight && body.style.maxHeight !== "none") {
      body.style.maxHeight = "none";
      button.textContent = "View less";
      if (fade) {
        fade.style.position = "static";
        fade.style.background = "none";
        fade.style.paddingTop = "0";
        fade.style.justifyContent = "flex-start";
        fade.style.alignItems = "flex-start";
        fade.style.marginTop = "8px";
      }
    } else {
      body.style.maxHeight = collapsedHeight;
      button.textContent = "View more";
      if (fade) {
        fade.style.position = "absolute";
        fade.style.background = "linear-gradient(to top, rgba(2,6,23,0.95), rgba(2,6,23,0))";
        fade.style.paddingTop = "2.5rem";
        fade.style.justifyContent = "flex-end";
        fade.style.alignItems = "flex-end";
        fade.style.marginTop = "0";
      }
      card.scrollIntoView({ behavior: "smooth", block: "start" });
    }
    return;
  }

  const isCollapsed = body.classList.contains("workout-log-card__body--collapsed");
  if (isCollapsed) {
    body.classList.remove("workout-log-card__body--collapsed");
    button.textContent = "View less";
  } else {
    body.classList.add("workout-log-card__body--collapsed");
    button.textContent = "View more";
    card.scrollIntoView({ behavior: "smooth", block: "start" });
  }
}

document.addEventListener("click", function(event) {
  const button = event.target.closest("[data-action='toggle-workout']");
  if (!button) return;
  toggleWorkoutCard(button);
});

window.toggleWorkout = function(button) {
  toggleWorkoutCard(button);
};
