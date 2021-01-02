const machineid = document.querySelector('#testshuffle');
const buttonid = document.querySelector('#shuffle');
const testshuffle = new SlotMachine(machineid, {
  active: 1,
  delay: 450,
  auto: 1500,
  randomize() {
    return 0;
  }
});

buttonid.addEventListener('click', () => testshuffle.shuffle(5));