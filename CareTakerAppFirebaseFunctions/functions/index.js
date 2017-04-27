var functions = require('firebase-functions');

// Create and Deploy Your First Cloud Functions
// https://firebase.google.com/docs/functions/write-firebase-functions


// Initialize the app
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// Is a function that lsitens to when the node "Notifications" is written 
// to. It's equivalent to ref.addValueEvenListener(...)
exports.sendNotification = functions.database.ref('Notifications')
.onWrite(event => {
	// store the value written to
	var request = event.data.val();
	var payload = {
		data: {
			username: "Randomz Experiments",
			email: "dummyemail@gmail.com"
		}
	};

	admin.messaging().sendToDevice(request.token, payload)
	.then(function(response) {
		console.log("Successfully sent message: ", response);
	})
	.catch(function(error) {
		console.log("Error sending messaage : ", error);
	})
})
