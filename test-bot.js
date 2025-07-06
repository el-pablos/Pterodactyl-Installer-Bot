// Test script to validate bot.js syntax and functionality
const fs = require('fs');

console.log('🔍 Testing bot.js for syntax errors...');

try {
  // Test if bot.js can be required without errors
  const botCode = fs.readFileSync('bot.js', 'utf8');
  
  // Check for common issues
  const issues = [];
  
  // Check for logStep usage outside of installpanel function
  const logStepMatches = botCode.match(/logStep\(/g);
  if (logStepMatches) {
    console.log(`⚠️  Found ${logStepMatches.length} logStep usages`);
    
    // Find lines with logStep
    const lines = botCode.split('\n');
    lines.forEach((line, index) => {
      if (line.includes('logStep(') && !line.includes('//')) {
        console.log(`   Line ${index + 1}: ${line.trim()}`);
        issues.push(`logStep usage at line ${index + 1}`);
      }
    });
  }
  
  // Check for undefined functions
  const undefinedFunctions = [
    'logStep', 'updateProgress', 'example'
  ];
  
  undefinedFunctions.forEach(func => {
    const regex = new RegExp(`${func}\\(`, 'g');
    const matches = botCode.match(regex);
    if (matches) {
      console.log(`⚠️  Found ${matches.length} usages of ${func}`);
    }
  });
  
  // Check if all required functions are defined
  const requiredFunctions = [
    'log', 'sendMessage', 'isOwner'
  ];
  
  requiredFunctions.forEach(func => {
    if (!botCode.includes(`const ${func} =`) && !botCode.includes(`function ${func}`)) {
      console.log(`❌ Missing function definition: ${func}`);
      issues.push(`Missing function: ${func}`);
    } else {
      console.log(`✅ Function found: ${func}`);
    }
  });
  
  // Check for syntax errors by trying to parse
  try {
    new Function(botCode);
    console.log('✅ Syntax check passed');
  } catch (syntaxError) {
    console.log(`❌ Syntax error: ${syntaxError.message}`);
    issues.push(`Syntax error: ${syntaxError.message}`);
  }
  
  if (issues.length === 0) {
    console.log('🎉 Bot validation completed successfully!');
    console.log('✅ No critical issues found');
  } else {
    console.log(`⚠️  Found ${issues.length} issues:`);
    issues.forEach(issue => console.log(`   - ${issue}`));
  }
  
} catch (error) {
  console.log(`❌ Error reading bot.js: ${error.message}`);
}

console.log('\n🔧 Testing simple bot...');

try {
  const simpleBotCode = fs.readFileSync('simple-bot.js', 'utf8');
  
  try {
    new Function(simpleBotCode);
    console.log('✅ Simple bot syntax check passed');
  } catch (syntaxError) {
    console.log(`❌ Simple bot syntax error: ${syntaxError.message}`);
  }
  
} catch (error) {
  console.log(`⚠️  simple-bot.js not found or error: ${error.message}`);
}

console.log('\n📋 Test completed!');
