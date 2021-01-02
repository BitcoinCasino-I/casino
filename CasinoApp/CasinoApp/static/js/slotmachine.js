let count = 0;
var index = 123;

const btnShuffle = document.querySelector('#randomizeButton');
const casino1 = document.querySelector('#casino1');
const casino2 = document.querySelector('#casino2');
const casino3 = document.querySelector('#casino3');
const mCasino1 = new SlotMachine(casino1, {
  active: 0,
  delay: 500,
  inViewport: false,
  randomize() {
      return Math.floor((index / 100) % 10)
  }
});
const mCasino2 = new SlotMachine(casino2, {
  active: 1,
  delay: 500,
  inViewport: false,
  direction: "down",
  randomize() {
    return Math.floor((index / 10) % 10)
  }
});
const mCasino3 = new SlotMachine(casino3, {
  active: 2,
  delay: 500,
  inViewport: false,
  randomize() {
      return Math.floor((index / 1) % 10)
  }
});

btnShuffle.addEventListener('click', () => {
    index = Math.floor(Math.random() * 6) * 100
    index += Math.floor(Math.random() * 6) * 10
    index += Math.floor(Math.random() * 6)
    mCasino1.shuffle(5);
    mCasino2.shuffle(5);
    mCasino3.shuffle(5);
  });