const slot1 = document.querySelector('#testshuffle');
const testshuffle = new SlotMachine(slot1, {
  active: 1,
  delay: 0,
  auto: 1500,
  randomize() {
    return {{ number }};
  }
});

testshuffle.shuffle(1));