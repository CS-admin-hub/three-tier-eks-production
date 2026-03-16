const mongoose = require("mongoose");

module.exports = async () => {
    try {
        const connectionParams = {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        };
        const useDBAuth = process.env.USE_DB_AUTH || false;
        if (useDBAuth) {
            connectionParams.user = process.env.MONGO_USERNAME;
            connectionParams.pass = process.env.MONGO_PASSWORD;
        }
        // Changed from MONGO_CONN_STR to MONGO_URI - matches K8s secret injection
        await mongoose.connect(
            process.env.MONGO_URI,
            connectionParams
        );
        console.log("Connected to database.");
    } catch (error) {
        console.log("Could not connect to database.", error);
    }
};