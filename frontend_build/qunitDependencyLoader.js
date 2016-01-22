// today, our spec files use qunit without requiring it.  That sort of sucks
// for webpack.  This adds a requirement for qunit to each spec file that's digested,
// and adds "qunit." to module and test calls.  Can be cleaned up later, but helps
// us get off the ground running tests in webpack from day one.

module.exports = function(source){
  var newSource = source;

  // add a qunit dependency to the dependency list
  newSource = newSource.replace(/define\(?\s*\[[^\]]/, function(match){
    return match.replace(/\[/, function(innerMatch){
      return innerMatch + "'qunit',";
    });
  });

  // don't want the comma if the list is empty
  newSource = newSource.replace(/define\(?\s*\[\s*\]/, function(match){
    return match.replace(/\[/, function(innerMatch){
      return innerMatch + "'qunit'";
    });
  });

  // add a qunit reference in the AMD callback to capture the qunit dependency
  newSource = newSource.replace(/\],\s*\(.+(\n.+)*\)\s*->/, function(match){
    return match.replace(/\],\s*\(/, function(innerMatch){
      return innerMatch + "qunit,";
    });
  });

  // don't want the comma if the list is empty
  newSource = newSource.replace(/\],\s*\(\s*\)\s*->/, function(match){
    return match.replace(/\],\s*\(/, function(innerMatch){
      return innerMatch + "qunit";
    });
  });

  // replace module and test calls with "qunit.module" and "qunit.test"
  newSource = newSource.replace(/^\s+module\s/gm, function(match){
    return match.replace("module", "qunit.module");
  });

  newSource = newSource.replace(/^\s+test\s/gm, function(match){
    return match.replace("test", "qunit.test");
  });

  return newSource;
};
