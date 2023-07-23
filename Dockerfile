# specify a base image
FROM julia:1.8 as installedoneeight

RUN apt update && apt install -q -y make gcc git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN git submodule init && git submodule update --recursive

RUN cd test/ && pwd && \
    julia --project=.. -e 'using Pkg; Pkg.add("TestReports"); Pkg.instantiate(); Pkg.build("TinyEKFGen"); Pkg.precompile()'


FROM installedoneeight as testoneeight

WORKDIR /app
COPY . .

#RUN cd test/ && \
#    julia --project=.. -e 'using TestReports; TestReports.test("TinyEKFGen", logfilepath="/mnt/artifacts")'

VOLUME ["/mnt/artifacts"]
#ENV GTEST_OUTPUT=xml:/mnt/artifacts/
#ENV GTEST_COLOR=1
