document.addEventListener('DOMContentLoaded', function () {
    pbEvents.subscribe("pb-refresh", "transcription", (ev) => {
        console.log(ev);
    });
});