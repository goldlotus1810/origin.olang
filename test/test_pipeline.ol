// Test G8 Pipeline — end to end
kt_learn("Mat Troi la ngoi sao gan Trai Dat nhat");
kt_learn("Mat Trang la ve tinh cua Trai Dat");
let _r = pipeline("Mat Troi");
if len(_r) > 0 { emit "PASS"; } else { emit "FAIL: pipeline empty"; };
