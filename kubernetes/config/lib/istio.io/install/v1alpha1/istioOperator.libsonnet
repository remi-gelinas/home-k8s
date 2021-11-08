local common = import 'common.libsonnet';

local apiVersion = 'install.istio.io/%s' % common.version;
local kind = 'IstioOperator';

{}