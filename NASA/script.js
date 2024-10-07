$(document).ready(function() {
  $('#myCarousel').carousel({
    interval: 3000, // Adjust the interval as needed (in milliseconds)
    transitionDuration: 1000 // Adjust the transition duration as needed (in milliseconds)
  });
});
// Example JavaScript function to register a student

async function registerStudent(username, email) {

const response = await fetch('http://127.0.0.1:8000//api/register/', {

method: 'POST',

headers: {

'Content-Type': 'application/json',

},

body: JSON.stringify({ username, email }),

});

if (response.ok) {

const data = await response.json();

console.log('Registration successful:', data);

} else {

const errorData = await response.json();

console.error('Registration failed:', errorData);

}

} 