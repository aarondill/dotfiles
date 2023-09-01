// The allow field should be an array of rules or undefined (the default is
// undefined). When provided, the rules specified are skipped and not reported.
const allow = ["dad-mom", "her-him", "his-hers", "he-she"];
// The profanitySureness field is a number (the default is 0). We use cuss, which
// has a dictionary of words that have a rating between 0 and 2 of how likely it
// is that a word or phrase is a profanity (not how “bad” it is):
const profanitySureness = 2;

export default {
  allow,
  profanitySureness,
};
