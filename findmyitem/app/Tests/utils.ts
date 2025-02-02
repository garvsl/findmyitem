export default function speak(text: string) {
    const utterance = new SpeechSynthesisUtterance(text);
  
    const voices = speechSynthesis.getVoices();
    if (voices.length > 0) {
      utterance.voice = voices[0];
    }
  
    speechSynthesis.speak(utterance);
  }