// backend/db.js 

const mongoose = require('mongoose'); 

  

const connection = async () => { 

    const connectionParams = { 

        useNewUrlParser: true, 

        useUnifiedTopology: true 

    }; 

    try { 

        // Changed from MONGO_CONN_STR to MONGO_URI 

        // MONGO_URI is injected from mongodb-secret K8s Secret (created by ESO) 

        // Value comes from AWS Secrets Manager: prod/three-tier/mongodb → uri 

        await mongoose.connect(process.env.MONGO_URI, connectionParams); 

        console.log('Connected to database successfully'); 

    } catch (error) { 

        console.error('Could not connect to database:', error.message); 

        process.exit(1); 

    } 

}; 

  

module.exports = connection; 
